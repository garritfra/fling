import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { randomUUID } from 'crypto';
import { Repository } from 'typeorm';
import { CreateUserInput } from './dto/create-user.input';
import { UpdateUserInput } from './dto/update-user.input';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  create(createUserInput: CreateUserInput): Promise<User> {
    const newUser = {
      id: randomUUID(),
      username: createUserInput.username,
    };

    return this.usersRepository.save(newUser);
  }

  findAll(): Promise<User[]> {
    return this.usersRepository.find();
  }

  findOne(id: string): Promise<User | null> {
    return this.usersRepository.findOneBy({ id });
  }

  async update(
    id: string,
    updateUserInput: UpdateUserInput,
  ): Promise<User | null> {
    const userToUpdate = await this.usersRepository.findOneBy({ id });

    if (userToUpdate) {
      const modifiedUser = {
        ...userToUpdate,
        ...updateUserInput,
      };
      await this.usersRepository.save(modifiedUser);
      return modifiedUser;
    }
    return null;
  }

  async remove(id: string): Promise<User | null> {
    const userToRemove = this.usersRepository.findOneBy({ id });
    if (userToRemove) {
      await this.usersRepository.delete({ id });
      return userToRemove;
    }
    return null;
  }
}
